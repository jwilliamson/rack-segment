## Rack-Segment

The idea of Segment is to split traffic on Rack based websites. The idea behind this is so AB testing can be applied to a website and experiments can be run.

What this gem does not do is record the results of an AB test.

## How it works
In short, its Middleware that segments traffic based on a key you specify. This can a value in a custom cookie, or a rack-session.

The middleware splits traffic and applies a Http Header to the incoming request. Eg A or B etc. This is then used by Experiment code to decide what value to provide when requested.

## How to apply Middleware

Simply implemention that uses Rack Sessions
```ruby
config.middleware.insert_before(Rack::Head, Segment)
```
