#ifndef SORBET_PROGRESSINDICATOR_H
#define SORBET_PROGRESSINDICATOR_H

#include "common/common.h"
#include "progressbar/progressbar.h"
#include <atomic>
#include <chrono>
#include <memory>
#include <thread>

class ProgressIndicator {
    const int progressExpected;
    std::string name;
    std::thread::id outputThreadId;
    std::unique_ptr<progressbar> progress;
    bool enabled;
    std::chrono::time_point<std::chrono::system_clock> lastReported;
    static std::chrono::time_point<std::chrono::system_clock> getCurrentTimeMillis() {
        return std::chrono::system_clock::now();
    }

public:
    ProgressIndicator(bool enabled, std::string name, int progressExpected);

    ~ProgressIndicator();

    void reportProgress(int current);
};

#endif // SORBET_PROGRESSINDICATOR_H
