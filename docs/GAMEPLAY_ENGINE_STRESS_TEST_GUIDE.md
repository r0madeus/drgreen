# Gameplay Engine Stress Test Guide

## Overview
This document serves as the guide for executing and evaluating the Botanical Haven Engine stress tests (introduced in Phase 44). The stress tests ensure that the core gameplay invariants hold under long-term execution and heavy load.

## Test Suites

The stress tests are located in `tests/` and are prefixed with `test_`:
- `test_gameplay_simulation.gd`: 14-day continuous simulation.
- `test_time_stress.gd`: Instant 30-day advancement.
- `test_world_transitions.gd`: 100+ scene loads.
- `test_random_actions.gd`: 10,000+ monkey-tested actions.

## Execution

Run the CLI test runner in stress-test mode:

```bash
godot --headless -s tests/cli_test_runner.gd
```

### Analyzing Results
- **Memory Leaks**: Watch for `Orphan StringName` or nodes left in memory after tests complete.
- **State Desyncs**: Any test failure indicating mismatched values between the expected component state and the serialized state points to a regression in the ECS framework.
- **Performance Drops**: If the simulation tick time increases significantly over the 14-day test, profile the `SafeExpressionEvaluator`.

## Triage
- **P0**: Fix immediately. Typically related to state corruption or core engine crashes.
- **P1**: Fix before release. Typically related to a specific gameplay system failing to process.
