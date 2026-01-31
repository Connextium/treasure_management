import { defineConfig } from '@wagmi/cli'
import { foundry } from '@wagmi/cli/plugins'


export default defineConfig({
  out: 'generated/MarketPredictorAbi.ts',
  plugins: [
    foundry({
      project: '../contracts',
      include: ['MarketPredictor.sol/**'],
    }),
  ],
})
