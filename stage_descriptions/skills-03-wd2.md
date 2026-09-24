In this stage, you'll add support for passing arguments to a skill.

### Placeholders

A skill that always does the same thing isn't much use. Real skills take input: *deploy* , *review*  .

Skills [accept input](https://code.claude.com/docs/en/skills#pass-arguments-to-skills) through placeholders in the body, which your program substitutes before sending the body to the model. There are two kinds:


| Placeholder                         | Replaced with                                  |
| ----------------------------------- | ---------------------------------------------- |
| `$ARGUMENTS`                        | Everything after the skill name, as one string |
| `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, … | A single argument, by zero-based position      |
| `$0`, `$1`, `$2`, …                 | Shorthand for sending single arguments         |


Both kinds can appear in the same body, and a placeholder can appear more than once.

### Substituting

Given this invocation:

```bash
$ ./your_program.sh -p "/apple staging eu-west"
```

`$ARGUMENTS` becomes `staging eu-west`, `$0` becomes `staging`, and `$1` becomes `eu-west`.

So a body of:

```markdown
Deploy to $0 in region $1. Full request was: $ARGUMENTS
```

is sent to the model as:

```
Deploy to staging in region eu-west. Full request was: staging eu-west
```

Arguments are split on whitespace. You don't need to handle quoting.

### Tests

The tester will create two skills and run your program twice.

The first skill's body echoes `$ARGUMENTS`, and is invoked with a random number:

```bash
$ ./your_program.sh -p "/apple 4127"
4127
```

The second skill's body echoes `$1` followed by `$0`, so the two random words it's invoked with come back in reverse order:

```bash
$ ./your_program.sh -p "/grape mango pear"
pear mango
```

The tester will verify that:

- The `$ARGUMENTS` substitution reproduces the full argument string
- The positional substitutions resolve to the right words, in the order the body asks for



### Notes

- Invoking a skill with no arguments should still work. Replace the placeholders with empty strings.
- Claude Code supports [several more substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions), including named arguments and session variables. We won't deal with them in this extension.

