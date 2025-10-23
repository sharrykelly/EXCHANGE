#!/bin/bash

# Create backup
cp tests/den_exchange.test.ts tests/den_exchange.test.ts.backup

# Fix patterns - replace expect(result).toBeOk(Cl.any()) with simpler checks
sed -i '' 's/expect(result).toBeOk(Cl.any());/\/\/ Just check if operation succeeded\n      const response = result as any;\n      expect(response.type).toBe(7); \/\/ ResponseOk type/' tests/den_exchange.test.ts

