import { http, createConfig } from "wagmi";
import { sepolia } from "wagmi/chains";

declare module "wagmi" {
	interface Register {
		config: typeof config;
	}
}

export const config = createConfig({
	chains: [sepolia],
	transports: {
		[sepolia.id]: http(),
	},
});
