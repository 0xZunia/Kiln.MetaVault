import { addressConfig } from "@/utils/addressConfig";
import { factoryABI } from "@/utils/factoryABI";
import { useReadContract } from "wagmi";

export function useGetMetaVault(user_address: `0x${string}` | undefined) {
	return useReadContract({
		abi: factoryABI,
		address: addressConfig.FACTORY_ADDRESS,
		functionName: "getMetaVault",
		args: [user_address ?? "0x"],
	});
}
