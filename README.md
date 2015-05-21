# Norton

## Installation

Add this line to your application's Gemfile:

    gem 'norton'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install norton

## Setup

You need to setup Norton with a redis connection, 

`Norton.setup url: <some redis connection url> `

Norton use `ConnectionPool` to hold redis connections, so you could also specify a pool size and a timeout like below. By default `pool = 1` and `timeout = 2`.

`Norton.setup url: <some redis connection url>, pool: 5, timeout: 5`

## Usage

### Counter

Simply include `Norton::Counter` in your model, and define a counter.

```
class User < ActiveRecord::Base
  include Norton::Counter
  
  counter :total_likes_count
end
```

- `users:<id>:total_likes_count` value will be created in redis to hold this counter.
- `user.total_likes_count=` to set the count to any number
- `user.incr_total_likes_count` to incr the counter by 1
- `user.decr_total_likes_count` to decr the counter by 1

You could also give a reset block:

```
class User < ActiveRecord::Base
  include Norton::Counter
  
  counter :total_likes_count do
    self.likes.count
  end
end
```

- `user.reset_total_likes_count` will evaluate the block and use the return value to set the counter


### Timestamp

Simply include `Norton::Timestamp` in your model, and define a timestamp.

```
class Note < ActiveRecord::Base
  include Norton::Timestamp
  
  timestamp :content_updated_at
end
```

- `notes:<id>:content_updated_at` is created in redis to hold this timestamp
- `note.content_updated_at` is created to get the timestamp
- `note.touch_content_update_at` is created to update the timestamp to `Time.now.to_i`

You could specify callbacks along with condition Procs of when to touch the timestamp:

```
class Note < ActiveRecord::Base
  include Norton::Timestamp
  
  timestamp :content_updated_at, before_save: Proc.new { title_changed? || content_changed? }
end
```

In the case above, `note.touch_content_updated_at` will be called when `before_save` is fired and `title_changed? || content_changed?` is fulfilled.
## Contributing

1. Fork it ( http://github.com/<my-github-username>/norton/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
