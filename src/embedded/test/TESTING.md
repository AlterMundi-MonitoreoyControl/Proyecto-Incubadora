# Testing guide

LibrePollo has unit tests that help us add new features while keeping maintenance effort contained.

We encourage contributors to write [tests](https://en.wikipedia.org/wiki/Unit_testing)  when adding new functionality and also while fixing [regressions](https://en.wikipedia.org/wiki/Regression_testing).

LibreMesh unit testing is based in the powerful [busted](https://lunarmodules.github.io/busted/) library which has a very good documentation.

## Install required sofotware
```
apt-get install luarocks
sudo luarocks install --server=https://luarocks.org/dev ltn12
sudo luarocks install luasockets
sudo luarocks install busted
sudo luarocks install json-lua 
sudo luarocks install inspect
```
## How to run the tests

Just execute `busted test_*` inside test folder.

## Testing directory structure

Test files for source module `foo.lua` live inside a `test` directory with its names begining with `test_`:

```
test/test_foo.lua

```

Testing utilities, fake libraries and integration tests live inside a root `test/` directory:

```
tests/test_some_integration_tests.lua
tests/test_other_general_tests.lua
tests/fake/bazlib.lua
tests/tests/test_bazlib.lua
```

## How to write tests

Here is a very simple test of a library `foo`:
```[lua]
local foo = require 'foo'

describe('foo library tests', function()
    it('very simple test of f_sum(a, b)', function()
        assert.is.equal(4, foo.f_sum(2, 2))
        assert.is.equal(2, foo.f_sum(2, 0))
        assert.is.equal(0, foo.f_sum(2, -2))
    end)
end)
```

