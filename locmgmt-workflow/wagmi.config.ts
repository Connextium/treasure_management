import { defineConfig } from '@wagmi/cli'
import { foundry } from '@wagmi/cli/plugins'

export default defineConfig({
  out: 'generated/LocManagementAbi.ts',
  plugins: [
    foundry({
      project: '../contracts',
      include: ['LocManagement.sol/**', 'Loc.sol/**'],
    }),
  ],
})
