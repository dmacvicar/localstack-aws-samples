# Spec: stepfunctions-lambda

## Overview

Demonstrates AWS Step Functions orchestrating multiple Lambda functions in a parallel workflow pattern.

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Three Lambda functions created (adam, cole, combine) | Must |
| FR-2 | State machine with Parallel state created | Must |
| FR-3 | Parallel branches execute concurrently | Must |
| FR-4 | Combine function merges results | Must |
| FR-5 | Final output matches expected format | Must |
| FR-6 | IAM roles created for Lambda and Step Functions | Must |

### Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-1 | Execution completes in under 30 seconds | Should |
| NFR-2 | State machine definition uses ASL standard | Must |

## Architecture

```
Input: {"adam": "LocalStack", "cole": "Stack"}
                    |
            [Parallel State]
           /                \
    [Adam Lambda]      [Cole Lambda]
           \                /
            [Combine Lambda]
                    |
Output: "Together Adam and Cole say 'LocalStack Stack'!!"
```

## Test Scenarios

### Scenario 1: Lambda Functions State
**Given** the deploy script has completed
**When** querying each Lambda function state
**Then** all three functions should be "Active"

### Scenario 2: State Machine Creation
**Given** the Lambda functions exist
**When** querying the state machine
**Then** status should be "ACTIVE"
**And** definition should contain Parallel state

### Scenario 3: Adam Lambda Direct Invocation
**Given** Adam Lambda function is active
**When** invoking with `{"input": {"adam": "LocalStack", "cole": "Stack"}}`
**Then** response should be "LocalStack"

### Scenario 4: Cole Lambda Direct Invocation
**Given** Cole Lambda function is active
**When** invoking with `{"input": {"adam": "LocalStack", "cole": "Stack"}}`
**Then** response should be "Stack"

### Scenario 5: Combine Lambda Direct Invocation
**Given** Combine Lambda function is active
**When** invoking with `{"input": ["LocalStack", "Stack"]}`
**Then** response should be "Together Adam and Cole say 'LocalStack Stack'!!"

### Scenario 6: State Machine Execution
**Given** state machine is active
**When** starting execution with `{"adam": "LocalStack", "cole": "Stack"}`
**Then** execution should complete with SUCCEEDED status
**And** output should be "Together Adam and Cole say 'LocalStack Stack'!!"

## Acceptance Criteria

- [ ] All 3 Lambda functions deploy successfully
- [ ] State machine is created with correct definition
- [ ] Individual Lambda functions return expected values
- [ ] Execution completes with SUCCEEDED status
- [ ] Final output matches expected format exactly
- [ ] Parallel branches both execute
