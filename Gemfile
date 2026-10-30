source "https://rubygems.org"

ruby file: ".ruby-version"

gem "jekyll", "~> 4.4.1"

# Liquid 4.0.4 requires bigdecimal without declaring it, and Ruby 3.4
# dropped it from the default gems. Today only google-protobuf pulls it
# in, so declare it here instead of relying on that.
gem "bigdecimal"

# Jekyll 4.4.1 requires logger without declaring it, and Ruby 4.0 drops
# it from the default gems. Today only listen pulls it in, so declare it
# here instead of relying on that.
gem "logger"
