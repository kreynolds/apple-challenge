# README

## Getting Started

The `db:seed` rake task is used to insert the 1,000,000 records. It truncates the table before insertion and gives you 5 seconds to hit ctrl-c if it was a mistake.

```
  bundle exec rake db:seed
  Truncating the visits table and inserting 1000000 records. Hit ctrl-c to abort ... 5 4 3 2 1
  Inserted 10000 rows

  ...

  Inserted 1000000 records in 61.5 seconds; 16260.57/s
```

## Notes

* webpacker/react has been installed but is not being used. Rather than demonstrate my inexperience with React, I'm going to leave this as a straight JSON API. If React is needed to accomplish a goal for production, I'm happy to learn it as necessary.
* There are some tricks that could be done to increase insert performance such as disabling/re-enabling indexes, but I don't do them here for the sake of simplicity. I inserted at around 18k/s (usually) and thats Good Enough™ until told otherwise.
* There are some additional things that could be done in the controllers with caching and more selective querying to increase the speed of the rendered result, but they add significant complexity and are thus omitted for this exercise. I assume knowledge of the techniques is sufficient and they are documented as options in the code.
* Alternate gems are available that can be used to speed up JSON serialization in certain circumstances but they are not used here. I'm assuming knowledge of them is sufficient.
* Unknown if this is an oversight or not, but the `hash` is set as not null, and the `id` is used as part of the `hash`. The only way to effect this safely is to make a separate query for `nextval()` or to use a postgresql trigger that sets the value of `hash` before insert. I opted for the latter as it was the most compatible with speed bulk insertion even though the example is given as ruby.
* Unspecified if things with no referer should be included as a top referer if applicable, I assumed so and reported the referer as `(direct)`
* This is my first use of Sequel as an ORM and as such, I avoided trying to shoehorn the more complicated queries into its DSL instead opting for raw SQL in the controller.
* I use `referer` per [RFC 1945](https://en.wikipedia.org/wiki/HTTP_referer#Etymology) instead of `referrer` as specified. Hopefully thats ok.
* I opt for a basic caching policy but it obviously can be modified depending on the business requirements. That will improve/reduce performance as necessary.
* I use a slightly different MD5 hash than the given example, using the full timestamp instead of just the date. I don't know for what purpose the hash was intended but not being immediately obvious, I used the full timestamp.