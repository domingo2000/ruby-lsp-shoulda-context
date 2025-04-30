[![Gem Version](https://badge.fury.io/rb/ruby-lsp-shoulda-context.svg)](https://badge.fury.io/rb/ruby-lsp-shoulda-context)
![Build Status](https://github.com/domingo2000/ruby-lsp-shoulda-context/actions/workflows/main.yml/badge.svg)

# RubyLsp::ShouldaContext

This gem provides support for [shoulda-context](https://github.com/thoughtbot/shoulda-context) using [ruby-lsp](https://github.com/Shopify/ruby-lsp/blob/main/lib/rubocop/cop/ruby_lsp/use_register_with_handler_method.rb)

## Installation

Add the gem to the application's Gemfile `:development` group:

```ruby
    gem 'ruby-lsp-shoulda-context', '~> 0.4.2', require: false
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
   gem install ruby-lsp-shoulda-context
```

## Usage

Just enjoy the magic of LSP with shoulda context tests!.

The extension can be enabled or disabled passing the settings

```json
"rubyLsp.addonSettings": {
  "Ruby LSP Shoulda Context": {
    "enabled": false
  }
}
```

(For example in `.vscode/settings.json` in VSCode)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/[domingo2000]/ruby-lsp-shoulda-context>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[domingo2000]/ruby-lsp-shoulda-context/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RubyLsp::ShouldaContext project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[domingo2000]/ruby-lsp-shoulda-context/blob/main/CODE_OF_CONDUCT.md).

## Roadmap

- [x] Make context runnable
- [x] Make should with string runnable
- [x] Make should with method runnable
- [x] Make exec method conditional to rails or Minitest setup
- [x] Make inner context or inner should with collisions with outer DSL not collide using full name of the test (Currently if 2 tests have the same name both are executed)
- [x] Provide grouping with classes that ends with "..Test" syntax (Note: The codelens is duplicated because lsp support minitest by default and LSP responses are merged)
- [ ] Provide support for Inner Classes

**Note**: This project is in very early stage and could have major bugs
