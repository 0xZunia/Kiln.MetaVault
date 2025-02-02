import { metaVaultABI } from "@/utils/metaVaultABI";
import { useAccount, useReadContract } from "wagmi";
import { useGetMetaVault } from "../factory";

export function useGetCurrentMetaVault() {
	const { address } = useAccount();
	const { data: vaultAddress, isLoading } = useGetMetaVault(address);

	const { data: activeVaults } = useReadContract({
		abi: metaVaultABI,
		address: vaultAddress,
		functionName: "getActiveVaults",
	});

	return { activeVaults, vaultAddress, isLoading };
}
