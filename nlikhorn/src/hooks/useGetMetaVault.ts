import { config } from "@/utils/config";
import { factoryABI } from "@/utils/factoryABI";
import { useReadContract } from "wagmi";

export function useGetMetaVault(address: `0x${string}` | undefined) {
	return useReadContract({
		abi: factoryABI,
		address: config.FACTORY_ADDRESS,
		functionName: "getMetaVault",
		args: [address ?? "0x"],
	});
}
