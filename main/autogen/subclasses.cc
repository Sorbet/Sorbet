#include "main/autogen/subclasses.h"
#include "common/FileOps.h"

using namespace std;
namespace sorbet::autogen {

optional<Subclasses::Map> Subclasses::listAllSubclasses(core::Context ctx, ParsedFile &pf,
                                                        const vector<string> &absolutePathsToIgnore,
                                                        const vector<string> &relativePathsToIgnore) {
    // We prepend "/" to `path` to mimic how `isFileIgnored` gets called elsewhere
    if (sorbet::FileOps::isFileIgnored("", fmt::format("/{}", pf.path), absolutePathsToIgnore, relativePathsToIgnore)) {
        return nullopt;
    }

    Subclasses::Map out;

    for (const Reference &ref : pf.refs) {
        DefinitionRef defn = ref.parent_of;

        if (!defn.exists()) {
            continue;
        }

        // Get fully-qualified parent name as string
        string parentName =
            fmt::format("{}", fmt::map_join(ref.resolved, "::", [&ctx](const core::NameRef &nm) -> string {
                            return nm.data(ctx)->show(ctx);
                        }));

        // Add child class to the set identified by its parent
        string childName = fmt::format(
            "{}", fmt::map_join(pf.showFullName(ctx, defn),
                                "::", [&ctx](const core::NameRef &nm) -> string { return nm.data(ctx)->show(ctx); }));

        out[parentName].insert(make_pair(childName, defn.data(pf).type));
    }

    return out;
}

// Generate all descendants of a parent class
// Recursively walks `childMap`, which stores the IMMEDIATE children of subclassed class.
void Subclasses::descendantsOf(const Subclasses::Map &childMap, const string &parentName, Subclasses::Entries &out) {
    if (!childMap.count(parentName)) {
        return;
    }
    const Subclasses::Entries &children = childMap.at(parentName);

    out.insert(children.begin(), children.end());
    for (const auto &[name, _type] : children) {
        Subclasses::descendantsOf(childMap, name, out);
    }
}

void Subclasses::maybeInsertChild(const string &parentName, const Subclasses::Entries &children, Subclasses::Map &out) {
    if (parentName.empty()) {
        // Child < NonexistentParent
        return;
    }
    out[parentName].insert(children.begin(), children.end());
}

// Manually patch the child map to account for inheritance that happens at runtime `self.included`
// Please do not add to this list.
// TODO(gwu) This shouldn't be public--hide this behind a new public method that realmain.cc calls
void Subclasses::patchChildMap(Subclasses::Map &childMap) {
    childMap["Opus::SafeMachine"].insert(childMap["Opus::Risk::Model::Mixins::RiskSafeMachine"].begin(),
                                         childMap["Opus::Risk::Model::Mixins::RiskSafeMachine"].end());

    childMap["Chalk::SafeMachine"].insert(childMap["Opus::SafeMachine"].begin(), childMap["Opus::SafeMachine"].end());

    childMap["Chalk::ODM::Model"].insert(make_pair("Chalk::ODM::Private::Lock", autogen::Definition::Type::Class));
}

vector<string> Subclasses::serializeSubclassMap(const Subclasses::Map &descendantsMap,
                                                const vector<string> &parentNames) {
    vector<string> descendantsMapSerialized;

    for (const string &parentName : parentNames) {
        if (!descendantsMap.count(parentName)) {
            continue;
        }

        descendantsMapSerialized.emplace_back(parentName);

        vector<string> serializedChildren;
        for (const auto &[name, type] : descendantsMap.at(parentName)) {
            if (type != autogen::Definition::Type::Class) {
                continue;
            }
            serializedChildren.emplace_back(fmt::format(" {}", name));
        }

        fast_sort(serializedChildren);
        descendantsMapSerialized.insert(descendantsMapSerialized.end(), make_move_iterator(serializedChildren.begin()),
                                        make_move_iterator(serializedChildren.end()));
    }

    return descendantsMapSerialized;
}

vector<string> Subclasses::genDescendantsMap(Subclasses::Map &childMap, vector<string> &parentNames) {
    Subclasses::patchChildMap(childMap);

    // Generate descendants for each passed-in superclass
    fast_sort(parentNames);
    Subclasses::Map descendantsMap;
    for (const string &parentName : parentNames) {
        Subclasses::Entries descendants;
        Subclasses::descendantsOf(childMap, parentName, descendants);
        descendantsMap.emplace(parentName, descendants);
    }

    return Subclasses::serializeSubclassMap(descendantsMap, parentNames);
};

} // namespace sorbet::autogen
