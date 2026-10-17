// ======================================================================================
// Mod Name: Map Waypoint Bug Fixes
// File: plugin/src/Main.cpp
// Author: Spuddeh
// Description: MappinSystem sends every mappin add/remove request through a 4096-slot
//              red::MultipleProducersSingleConsumerLockFreeQueue. Nothing drains it while a save
//              loads, and once it is full Push returns false; the Register* callers ignore that,
//              so the request is destroyed and its mappin never exists. The fast-travel rebuild
//              is queued last, so its pins go first.
//
//              Push keeps every request the queue refuses, in order, and Pop hands them to the
//              consumer once the queue runs dry. While anything is kept, new requests are kept
//              behind it, so the consumer sees requests in the order they were made.
// Mod Version: 1.1.0
// Credits: Spuddeh. Fixes a base-game (vanilla) bug.
// ======================================================================================
#include <RED4ext/RED4ext.hpp>

#include <atomic>
#include <cstdint>
#include <deque>
#include <mutex>
#include <unordered_map>

namespace
{
RED4ext::v1::PluginHandle g_handle = nullptr;
const RED4ext::v1::Sdk* g_sdk = nullptr;

// red::SharedStorage<game::mappins::IMappinRequest, AtomicSharedStorage>: an instance pointer and a
// reference-count pointer. Moving one is copying both and nulling the source, which is what the
// engine's own Push and Pop do with it.
struct Request
{
    void* instance;
    void* refCount;
};
static_assert(sizeof(Request) == 16);

// Name hash -> function. The comment above each is the mangled name the hash belongs to.
namespace Fn
{
// ?Push@?$MultipleProducersSingleConsumerLockFreeQueue@V?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@red@@$0BAAA@@red@@QEAA_N$$QEAV?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@2@@Z
constexpr std::uint32_t Push = 0x0B4A5D27;
using Push_t = bool (*)(void* aQueue, Request* aRequest);

// ?Pop@?$MultipleProducersSingleConsumerLockFreeQueue@V?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@red@@$0BAAA@@red@@QEAA_NAEAV?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@2@@Z
constexpr std::uint32_t Pop = 0x05FD5C5E;
using Pop_t = bool (*)(void* aQueue, Request* aOut);

// ??1?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@red@@QEAA@XZ
constexpr std::uint32_t Release = 0xF7D023D1;
using Release_t = void (*)(Request* aRequest);

// ??1?$MultipleProducersSingleConsumerLockFreeQueue@V?$SharedStorage@UIMappinRequest@mappins@game@@VAtomicSharedStorage@internal@red@@X@red@@$0BAAA@@red@@QEAA@XZ
constexpr std::uint32_t Destroy = 0xAF3E3A1F;
using Destroy_t = void (*)(void* aQueue);
} // namespace Fn

Fn::Push_t g_push = nullptr;
Fn::Pop_t g_pop = nullptr;
Fn::Release_t g_release = nullptr;
Fn::Destroy_t g_destroy = nullptr;

// Kept requests per queue. Only MappinSystem owns a queue of this type, but keying by queue keeps
// a second instance correct instead of crossing their requests.
std::mutex g_lock;
std::unordered_map<void*, std::deque<Request>> g_kept;
std::atomic<std::size_t> g_keptCount{0};
std::size_t g_recoveredThisBurst = 0;

bool PushDetour(void* aQueue, Request* aRequest)
{
    if (g_keptCount.load(std::memory_order_acquire) == 0 && g_push(aQueue, aRequest))
        return true;

    std::lock_guard guard(g_lock);
    g_kept[aQueue].push_back(*aRequest);
    aRequest->instance = nullptr;
    aRequest->refCount = nullptr;
    g_keptCount.fetch_add(1, std::memory_order_release);
    return true;
}

bool PopDetour(void* aQueue, Request* aOut)
{
    if (g_pop(aQueue, aOut))
        return true;
    if (g_keptCount.load(std::memory_order_acquire) == 0)
        return false;

    Request next{};
    {
        std::lock_guard guard(g_lock);
        const auto it = g_kept.find(aQueue);
        if (it == g_kept.end() || it->second.empty())
            return false;
        next = it->second.front();
        it->second.pop_front();
        g_keptCount.fetch_sub(1, std::memory_order_release);
        ++g_recoveredThisBurst;
        if (it->second.empty())
        {
            g_sdk->logger->InfoF(g_handle, "Recovered %zu mappin requests the queue refused",
                                 g_recoveredThisBurst);
            g_recoveredThisBurst = 0;
        }
    }

    // The engine's Pop releases whatever the out slot held before it moves the request in.
    Request previous = *aOut;
    *aOut = next;
    if (previous.instance || previous.refCount)
        g_release(&previous);
    return true;
}

void DestroyDetour(void* aQueue)
{
    std::deque<Request> orphans;
    {
        std::lock_guard guard(g_lock);
        const auto it = g_kept.find(aQueue);
        if (it != g_kept.end())
        {
            orphans.swap(it->second);
            g_kept.erase(it);
            g_keptCount.fetch_sub(orphans.size(), std::memory_order_release);
        }
    }
    for (auto& request : orphans)
        g_release(&request);
    g_destroy(aQueue);
}

template<typename T>
bool Resolve(T& aOut, std::uint32_t aHash, const char* aName)
{
    aOut = reinterpret_cast<T>(RED4ext::UniversalRelocBase::Resolve(aHash));
    if (!aOut)
        g_sdk->logger->ErrorF(g_handle, "%s did not resolve", aName);
    return aOut != nullptr;
}

bool Hook(std::uint32_t aHash, void* aDetour, void** aOriginal, const char* aName)
{
    const auto target = RED4ext::UniversalRelocBase::Resolve(aHash);
    if (!target || !g_sdk->hooking->Attach(g_handle, reinterpret_cast<void*>(target), aDetour, aOriginal))
    {
        g_sdk->logger->ErrorF(g_handle, "Hooking %s failed", aName);
        return false;
    }
    return true;
}

bool AttachHooks()
{
    if (!Resolve(g_release, Fn::Release, "SharedStorage<IMappinRequest>::~SharedStorage"))
        return false;
    return Hook(Fn::Push, reinterpret_cast<void*>(&PushDetour), reinterpret_cast<void**>(&g_push), "Push") &&
           Hook(Fn::Pop, reinterpret_cast<void*>(&PopDetour), reinterpret_cast<void**>(&g_pop), "Pop") &&
           Hook(Fn::Destroy, reinterpret_cast<void*>(&DestroyDetour), reinterpret_cast<void**>(&g_destroy),
                "~MultipleProducersSingleConsumerLockFreeQueue");
}
} // namespace

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle aHandle, RED4ext::v1::EMainReason aReason,
                                        const RED4ext::v1::Sdk* aSdk)
{
    if (aReason == RED4ext::v1::EMainReason::Load)
    {
        g_handle = aHandle;
        g_sdk = aSdk;
        return AttachHooks();
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* aInfo)
{
    aInfo->name = L"MapWaypointBugFixes";
    aInfo->author = L"Spuddeh";
    aInfo->version = RED4EXT_V1_SEMVER(1, 1, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    aInfo->sdk = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT std::uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
