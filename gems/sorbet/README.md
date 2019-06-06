# gems/sorbet/

This folder contains the source for the `'sorbet'` gem. This gem serves two
purposes:

- It depends on `'sorbet-static'`, which includes the release executable of the
  Sorbet static type checker. Thus adding `'sorbet'` to a Gemfile fetches a
  pre-built version of Sorbet behind the scenes.

- It contains the `srb` executable. This is a wrapper script that we use for:

  - initializing a Sorbet project / generating RBI files
  - finding & running the Sorbet executable in `'sorbet-static'` to type check a
    project

This README is for contributors. Here are some docs for how to use this gem:

- <https://sorbet.org/docs/adopting>
- <https://sorbet.org/docs/rbi>


## Project structure

A quick overview of the project structure:

```
.
├── bin/
│   ├── srb              → The main CLI entry point (Bash)
│   └── srb-rbi          → The main Ruby entrypoint (called by `srb`)
├── lib/                 → Supporting files for `srb-rbi`
│   └── ···
├── test/
│   ├── ···
│   └── snapshot/        → Snapshot tests for `srb init`
│       ├── partial/
│       └── total/
├── Gemfile
└── sorbet.gemspec
```

- The main entry point is `bin/srb`. It's written in Bash in an attempt to avoid
  the performance cost of forking a Ruby process just to type check.

  (Forking a Ruby process = ~200ms; Sorbet can frequently type check an entire
  project in as much time.)

- When generating RBI files (i.e., not type checking a project), `bin/srb` calls
  into `bin/srb-rbi`, which as a number of subcommands. This is where all the
  actual RBI generation logic is.


## Environment variables

There are a number of environment variables that `srb` reads from to change it's
behavior:

- `SRB_SORBET_EXE`

  Overrides the `sorbet` executable used by all calls to `srb tc`.
  (The default is to find and use the version inside the `'sorbet-static'` gem.)

- `XDG_CACHE_HOME`

  The `srb` command keeps a cache of `sorbet-typed` on disk. Setting
  `XDG_CACHE_HOME` will change the folder where the `sorbet-typed` cache will
  be. (The default when this is unset is to use `$HOME/.cache/`.)

- `SRB_SORBET_TYPED_REVISION`

  Pin the sorbet-typed cache to a specific revision. (The default is to fetch
  and use the latest `master` commit.)


## Running locally

To run `srb` locally requires first being able to build the `sorbet` executable
itself. See the top-level README.md in this repo.

Once you've built `sorbet`, to run `srb`:

```
❯ SRB_SORBET_EXE=bazel-bin/main/sorbet bin/srb ...
```

To make this easier, you can either

- put `sorbet` on your `PATH` (see the top-level README.md for suggestions), or
- write a test, and use the test harness (see [Running tests](#running-tests)).


## Running tests

To run all the tests:

```
test/snapshot/driver.sh
```

The driver.sh output should show you how to re-run a single failing test, but an
example is like this:

```
test/snapshot/test_one.sh test/snapshot/total/empty
```

There are more options to `driver.sh` and `test_one.sh`. For the full list of
available options, use `--help`:

```
test/snapshot/driver.sh --help

test/snapshot/test_one.sh --help
```


## Writing tests

It's currently only possible to test `srb init`, not any other subcommand.

We use two kinds of tests to test `srb init`: total snapshot tests and partial
snapshot tests. The anatomy of a snapshot test looks like this:

```
test/snapshot/(total|partial)/<testname>/
├── expected/
│   ├── sorbet/
│   │   └── ···
│   ├── err.log
│   └── out.log
└── src/
    ├── Gemfile
    ├── Gemfile.lock
    └── ···
```

So a snapshot test consists of a `src/` folder declaring a small Ruby project,
with a `Gemfile`, `Gemfile.lock`, and zero or more Ruby files. The test then
also has an `expected` folder, which can be used to snapshot

- the stdout of running `srb init` (`out.log`)
- the stderr of running `srb init` (`err.log`)
- resulting `sorbet/` folder for this project

The difference between a total snapshot test and a partial snapshot test deals
with the `expected/` folder:

- For a total test, all three of the actual `out.log`, actual `err.log`, and
  actual `sorbet/` folder must exactly match (no more, no less) what is in the
  `expected/` folder.

- For a partial test, only the files explicitly mentioned in the `expected/`
  folder must match. The actual output of `srb init` might contain more than is
  snapshotted.

  Note that the entire `expected/` folder is optional for a partial test. Such a
  test will merely assert that `srb init` runs to termination without error.

We **prefer partial tests** because they're more specific and more robust to
changes in implementation details. Use total tests only when you must test the
absence of some behavior.

> **Note**: It's currently not possible to test the contents of
> `sorbet/rbi/hidden-definitions`.
>
> See <https://github.com/stripe/sorbet/issues/593>.

### Updating tests

When it **is** necessary to update a snapshot test, run one of:

```
test/snapshot/driver.sh --update

test/snapshot/test_one.sh <testname> --update
```

### Creating new partial tests

A total test can never be empty, so to record a new total test, just use
`--update`, like above.

Since a partial test is allowed to have an empty `expected/` folder, there's no
difference between "a new partial test" and "an existing partial test that just
asserts no errors". As such, to populate the `expected/` folder of a new partial
test, use the `--record` flag:

```
test/snapshot/test_one.sh <testname> --update --record
```

### Debugging tests

To use `binding.pry` to debug a test, edit your test case and/or the `srb` gem
to require and call `pry`, and then pass the `--debug` flag when running the
test:

```
test/snapshot/test_one.sh <testname> --debug
```
