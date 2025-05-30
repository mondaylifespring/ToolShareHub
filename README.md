# ToolShareHub: Community Tool Lending Library

ToolShareHub is a decentralized protocol built on Clarity that enables community members to share tools and equipment with neighbors, reducing waste and promoting resource efficiency.

## Overview

ToolShareHub creates a collaborative consumption model for tools and equipment that often sit idle in garages and workshops. The protocol allows tool owners to list their items for community borrowing, specify lending terms, and track the entire borrowing lifecycle on the blockchain.

## Features

- List tools with detailed information (name, description, category, condition)
- Request to borrow tools for specific durations
- Approve or deny borrowing requests
- Track tool availability and borrowing history
- Transparent owner verification and tool return process

## Contract Functions

### Public Functions

- `add-tool`: Add a tool to the community lending library
- `remove-tool`: Remove a tool from active listings
- `request-borrow`: Request to borrow a specific tool
- `approve-borrow`: Approve a borrowing request
- `deny-borrow`: Reject a borrowing request
- `return-tool`: Mark a tool as returned
- `get-tool`: Retrieve details about a specific tool
- `get-owner`: Get the owner of a specific tool

### Constants

- Minimum duration requirements
- Validation for tool categories and conditions
- Error codes for various failure scenarios

## Data Structure

Each tool listing contains:
- Owner information (principal)
- Tool name (string)
- Description (string)
- Tool category
- Condition
- Status
- Maximum lending days

## Getting Started

To interact with the ToolShareHub:

1. Deploy the contract to a Stacks blockchain node
2. Call the contract functions using a compatible wallet or Clarity development environment
3. List your tools for community borrowing
4. Request to borrow tools from other community members

## Future Development

- Implement tool deposit system
- Add maintenance tracking functionality
- Create community tool wishlist
- Expand category and condition classifications
- Develop tool usage tutorials and safety guides