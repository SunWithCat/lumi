#pragma once

#include <CubismFramework.hpp>
#include <ICubismAllocator.hpp>

/**
 * Cubism SDK 内存分配器
 */
class Live2DAllocator : public Csm::ICubismAllocator {
public:
    void* Allocate(const Csm::csmSizeType size) override {
        return malloc(size);
    }

    void Deallocate(void* memory) override {
        free(memory);
    }

    void* AllocateAligned(const Csm::csmSizeType size, const Csm::csmUint32 alignment) override {
        size_t offset, shift, alignedAddress;
        void* allocation;
        void** preamble;

        offset = alignment - 1 + sizeof(void*);
        allocation = Allocate(size + static_cast<Csm::csmSizeType>(offset));
        alignedAddress = reinterpret_cast<size_t>(allocation) + sizeof(void*);
        shift = alignedAddress % alignment;

        if (shift) {
            alignedAddress += (alignment - shift);
        }

        preamble = reinterpret_cast<void**>(alignedAddress);
        preamble[-1] = allocation;

        return reinterpret_cast<void*>(alignedAddress);
    }

    void DeallocateAligned(void* alignedMemory) override {
        void** preamble = reinterpret_cast<void**>(alignedMemory);
        Deallocate(preamble[-1]);
    }
};
