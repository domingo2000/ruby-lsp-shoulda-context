# Rails LSP extension for shoulda-context tests

This gem provides support for [shoulda-context](https://github.com/thoughtbot/shoulda-context) using [ruby-lsp](https://github.com/Shopify/ruby-lsp/blob/main/lib/rubocop/cop/ruby_lsp/use_register_with_handler_method.rb)

Currently it works fine with the

## Roadmap:

- [x] Make context runnable
- [x] Make should with string runnable
- [ ] Make should with method runnable
- [ ] Make exec method conditional to rails or Minitest setup
- [ ] Make inner context or inner should with collissions with outer DSL not collide using full name of the test (Currently if 2 tests have the same name both are executed)
- [x] Provide grouping with classes that ends with "..Test" syntax (Note: The codelens is duplicated becuase lsp support minitest by default and LSP responses are merged)

**Note**: This project is in very early stage and could have major bugs
