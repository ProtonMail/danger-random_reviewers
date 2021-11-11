# danger-random_reviewers

A Danger plugin to assign random reviewers form a pre-defined list.

## Installation

    $ gem install danger-random_reviewers

## Usage

You need to call the `assign` method, either providing a sublist of users that can be assigned:

    random_reviewers.assign(['vbrison', 'jmartin'])

Or no list at all to select from all available reviewers:

    random_reviewers.assign()

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
