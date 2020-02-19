#include "common/Timer.h"
using namespace std;
namespace sorbet {

Timer::Timer(spdlog::logger &log, ConstExprStr name, FlowId prev, initializer_list<pair<ConstExprStr, string>> args,
             chrono::time_point<chrono::steady_clock> start)
    : log(log), name(name), prev(prev), self{0}, args(args), start(start) {}

Timer::Timer(spdlog::logger &log, ConstExprStr name, FlowId prev, initializer_list<pair<ConstExprStr, string>> args)
    : Timer(log, name, prev, args, chrono::steady_clock::now()){};

Timer::Timer(spdlog::logger &log, ConstExprStr name, initializer_list<pair<ConstExprStr, string>> args)
    : Timer(log, name, FlowId{0}, args){};

Timer::Timer(const shared_ptr<spdlog::logger> &log, ConstExprStr name, FlowId prev,
             initializer_list<pair<ConstExprStr, string>> args)
    : Timer(*log, name, prev, args){};

Timer::Timer(const shared_ptr<spdlog::logger> &log, ConstExprStr name,
             initializer_list<pair<ConstExprStr, string>> args)
    : Timer(*log, name, args){};

Timer::Timer(const shared_ptr<spdlog::logger> &log, ConstExprStr name)
    : Timer(*log, name, initializer_list<pair<ConstExprStr, string>>()){};
Timer::Timer(const shared_ptr<spdlog::logger> &log, ConstExprStr name, FlowId prev) : Timer(*log, name, prev, {}){};

Timer::Timer(spdlog::logger &log, ConstExprStr name)
    : Timer(log, name, initializer_list<pair<ConstExprStr, string>>()){};
Timer::Timer(spdlog::logger &log, ConstExprStr name, FlowId prev)
    : Timer(log, name, prev, initializer_list<pair<ConstExprStr, string>>()){};

int getGlobalTimingId() {
    static atomic<int> counter = 1;
    return ++counter;
}

FlowId Timer::getFlowEdge() {
    if (this->self.id == 0) {
        this->self.id = getGlobalTimingId();
    }
    return this->self;
}

void Timer::cancel() {
    this->canceled = true;
}

Timer Timer::clone(ConstExprStr name) {
    Timer forked(log, name, prev, {}, start);
    forked.args = args;
    forked.tags = tags;
    forked.canceled = canceled;
    return forked;
}

void Timer::setTag(ConstExprStr name, ConstExprStr value) {
    // Check if tag is already set; if so, update value.
    for (auto &tag : tags) {
        const auto tagName = tag.first;
        if (tagName.size == name.size && strncmp(tagName.str, name.str, tagName.size) == 0) {
            tag.second = value;
            return;
        }
    }
    // Add new tag.
    tags.push_back(make_pair(name, value));
}

Timer::~Timer() {
    auto clock = chrono::steady_clock::now();
    auto dur = clock - start;
    if (!canceled && dur > std::chrono::milliseconds(1)) {
        // the trick ^^^ is to skip double comparison in the common case and use the most efficient representation.
        auto dur = std::chrono::duration<double, std::milli>(clock - start);
        log.debug("{}: {}ms", this->name.str, dur.count());
        sorbet::timingAdd(this->name, start, clock, move(args), move(tags), self, prev);
    }
}

} // namespace sorbet
