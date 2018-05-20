# TODO

* `common.sh`: `import()` - move the function to a separate and exclusive file
  and source it, because now `eval` in that function mess with line numbering
  in `common.sh` file (it is important for `die()` function, when we show the
  line number of the `caller`)

  * Hint: every function with `eval` should be in separate file. Maybe make
    one file with only `eval` function in it? And it will `eval` any argument
    it receive. To consider.

* autocompletion for command parameters values (not only parameter names)

# DONE

* Autocompletion for parameter names