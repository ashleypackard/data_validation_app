# README

* Ruby version - 2.4.3
* Rails version - 5.2.1

# Setup

1. Install ruby/rails corresponding to your environment instructions.
2. `git clone data_validation_app@github.com`
3. `bundle install`
4. `rails s`
5. Using curl or postman hit this route: `http://localhost:3000/api/v1/validate` or `http://localhost:3000/api/v1/validate?contraint=5`

# Content
This app has one controller, the ValidationsController `data_validation_app/app/controllers/api/v1/validations_controller.rb`. Its purpose is to validate the given CSV file `data_validation_app/storage/normal_data.csv`. It makes use of the [Levenshtein gem](https://github.com/dbalatero/levenshtein-ffi) which calculates the distance between two strings (ie. how many changes it takes to get from the first string to the second string).

The API has one optional parameter that can be used to constrain the first pass at the data row, it is defaulted to 5. So if the current row has a distance of 5 or less from another row, it is considered a duplicate. If that check does not pass, the row will be compared against `IMPORTANT_HEADERS` which are assumed to be the `first_name`, `last_name`, `email`, and `phone` fields (which could also be another parameter passed to the route). The specifed fields of the current row must match a majority of another row to be deemed a dupilcate (in this case 3 or 4 matches). Addressed in the comments of the method are various other ways this could have been handled dependent on what precendence each field should take.

The API has one route, `/validate`, which outputs JSON in the format:
```
{
  "status": "ok",
  "potential_duplicates": {},
  "non_duplicates": []
}
```
