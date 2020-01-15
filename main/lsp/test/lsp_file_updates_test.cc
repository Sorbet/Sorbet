#include "gtest/gtest.h"
// has to go first as it violates are requirements

#include "ast/ast.h"
#include "core/NameHash.h"
#include "core/core.h"
#include "main/lsp/json_types.h"

namespace sorbet::realmain::lsp::test {

using namespace std;
using namespace sorbet::realmain::lsp;

namespace {
u4 nextHash = 0;
core::FileHash getFileHash() {
    core::FileHash hash;
    hash.definitions.hierarchyHash = nextHash++;
    return hash;
}

ast::ParsedFile getParsedFile(core::FileRef fref) {
    auto lit = make_unique<ast::Literal>(core::Loc(fref, 0, 1), core::Types::Integer());
    return ast::ParsedFile{move(lit), fref};
}

shared_ptr<core::File> makeFile(std::string path, std::string contents) {
    return make_shared<core::File>(move(path), move(contents), core::File::Type::Normal);
}

void addFile(LSPFileUpdates &updates, core::FileRef fref, std::string path, std::string contents) {
    updates.updatedFiles.push_back(makeFile(move(path), move(contents)));
    updates.updatedFileIndexes.push_back(getParsedFile(fref));
    updates.updatedFileHashes.push_back(getFileHash());
}

} // namespace

TEST(LSPFileUpdatesTest, MergeOlderVersions) {
    LSPFileUpdates oldUpdates;
    oldUpdates.versionStart = 4;
    oldUpdates.versionEnd = 10;

    LSPFileUpdates newUpdates;
    newUpdates.versionStart = 10;
    newUpdates.versionEnd = 14;

    newUpdates.mergeOlder(oldUpdates);

    EXPECT_EQ(4, newUpdates.versionStart);
    EXPECT_EQ(14, newUpdates.versionEnd);
}

TEST(LSPFileUpdatesTest, MergeOlderCancellationExpected) {
    LSPFileUpdates oldUpdates;
    oldUpdates.cancellationExpected = true;

    LSPFileUpdates newUpdates;
    newUpdates.cancellationExpected = false;

    newUpdates.mergeOlder(oldUpdates);
    EXPECT_TRUE(newUpdates.cancellationExpected);

    oldUpdates.cancellationExpected = false;
    newUpdates.mergeOlder(oldUpdates);
    EXPECT_TRUE(newUpdates.cancellationExpected);
}

TEST(LSPFileUpdatesTest, MergeOlderHasNewFiles) {
    LSPFileUpdates oldUpdates;
    oldUpdates.hasNewFiles = true;

    LSPFileUpdates newUpdates;
    newUpdates.hasNewFiles = false;

    newUpdates.mergeOlder(oldUpdates);
    EXPECT_TRUE(newUpdates.hasNewFiles);

    oldUpdates.hasNewFiles = false;
    newUpdates.mergeOlder(oldUpdates);
    EXPECT_TRUE(newUpdates.hasNewFiles);
}

TEST(LSPFileUpdatesTest, MergeUpdatedFiles) {
    LSPFileUpdates oldUpdates;
    oldUpdates.versionStart = 4;
    oldUpdates.versionEnd = 10;
    addFile(oldUpdates, core::FileRef(1), "foo.rb", "foo");
    addFile(oldUpdates, core::FileRef(2), "bar.rb", "oldcontents");

    LSPFileUpdates newUpdates;
    newUpdates.versionStart = 10;
    newUpdates.versionEnd = 14;
    addFile(newUpdates, core::FileRef(2), "bar.rb", "newcontents");
    addFile(newUpdates, core::FileRef(3), "baz.rb", " ");

    newUpdates.mergeOlder(oldUpdates);
    ASSERT_EQ(3, newUpdates.updatedFiles.size());
    ASSERT_EQ(3, newUpdates.updatedFileIndexes.size());
    ASSERT_EQ(3, newUpdates.updatedFileHashes.size());

    UnorderedMap<string, int> fileIndexes;
    int i = -1;
    for (auto &f : newUpdates.updatedFiles) {
        i++;
        auto path = string(f->path());
        EXPECT_FALSE(fileIndexes.contains(path));
        fileIndexes[move(path)] = i;
    }
    {
        ASSERT_TRUE(fileIndexes.contains("bar.rb"));
        int i = fileIndexes["bar.rb"];
        EXPECT_EQ("newcontents", newUpdates.updatedFiles[i]->source());
        EXPECT_EQ(2, newUpdates.updatedFileIndexes[i].file.id());
        EXPECT_NE(oldUpdates.updatedFileHashes[1].definitions.hierarchyHash,
                  newUpdates.updatedFileHashes[i].definitions.hierarchyHash);
    }

    {
        ASSERT_TRUE(fileIndexes.contains("foo.rb"));
        int i = fileIndexes["foo.rb"];
        EXPECT_EQ("foo", newUpdates.updatedFiles[i]->source());
        EXPECT_EQ(1, newUpdates.updatedFileIndexes[i].file.id());
        EXPECT_EQ(oldUpdates.updatedFileHashes[0].definitions.hierarchyHash,
                  newUpdates.updatedFileHashes[i].definitions.hierarchyHash);
    }

    {
        ASSERT_TRUE(fileIndexes.contains("baz.rb"));
        EXPECT_EQ(" ", newUpdates.updatedFiles[fileIndexes["baz.rb"]]->source());
    }
}

TEST(LSPFileUpdatesTest, Copy) {
    LSPFileUpdates updates;
    updates.versionStart = 0;
    updates.versionEnd = 10;
    updates.cancellationExpected = true;
    updates.canTakeFastPath = true;
    updates.hasNewFiles = true;
    updates.updatedGS = unique_ptr<core::GlobalState>(nullptr);
    addFile(updates, core::FileRef(1), "foo.rb", "foo");
    addFile(updates, core::FileRef(2), "bar.rb", "bar");

    LSPFileUpdates copy = updates.copy();
    EXPECT_EQ(0, copy.versionStart);
    EXPECT_EQ(10, copy.versionEnd);
    EXPECT_TRUE(copy.cancellationExpected);
    EXPECT_TRUE(copy.canTakeFastPath);
    EXPECT_TRUE(copy.hasNewFiles);
    EXPECT_FALSE(copy.updatedGS.has_value());

    ASSERT_EQ(2, copy.updatedFiles.size());
    ASSERT_EQ(2, copy.updatedFileHashes.size());
    ASSERT_EQ(2, copy.updatedFileIndexes.size());

    EXPECT_EQ("foo.rb", copy.updatedFiles[0]->path());
    EXPECT_EQ("foo", copy.updatedFiles[0]->source());
    EXPECT_EQ("bar.rb", copy.updatedFiles[1]->path());
    EXPECT_EQ("bar", copy.updatedFiles[1]->source());

    EXPECT_EQ(1, copy.updatedFileIndexes[0].file.id());
    EXPECT_EQ(2, copy.updatedFileIndexes[1].file.id());

    EXPECT_EQ(updates.updatedFileHashes[0].definitions.hierarchyHash,
              copy.updatedFileHashes[0].definitions.hierarchyHash);
    EXPECT_EQ(updates.updatedFileHashes[1].definitions.hierarchyHash,
              copy.updatedFileHashes[1].definitions.hierarchyHash);
}

} // namespace sorbet::realmain::lsp::test