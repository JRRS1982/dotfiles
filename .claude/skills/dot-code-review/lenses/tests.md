# Lens: tests

Question: if this change is wrong, what does a user suffer, and does a test catch it at the cheapest layer?

For each behavioural change in the diff, state the failure scenario in one sentence: "if this is wrong, a user can X." Then check the tests the diff adds or changes, and the existing tests for the touched code (grep the repo's test directories for the modified function, component, or route names).

Flag:

- a behavioural change with a nameable user-visible harm and no test at any layer
- a test at the wrong layer: pure logic tested only end to end, or a database or service boundary tested only through mocks
- a test that asserts implementation details and would fail on a harmless refactor
- a test that cannot fail: it asserts on a mocked return value, or has no assertion on the changed behaviour
- a deleted or skipped test the diff does not explain

Do not ask for coverage of trivial code, and do not restate what already exists. Severity: a missing test for a stated harm on a write, auth, or money path is Blocking. Otherwise Suggested. Quote the changed code and name the test file that should hold the test.
