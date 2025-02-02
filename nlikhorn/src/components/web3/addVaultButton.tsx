import { useGetCurrentMetaVault } from "@/hooks/metaVault";
import { metaVaultABI } from "@/utils/metaVaultABI";
import { IconButton } from "@chakra-ui/react";
import { LuPlus } from "react-icons/lu";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";

export function AddVaultButton({
	vaultAddress,
}: {
	vaultAddress: string;
}) {
	const { vaultAddress: metaVaultAddress } = useGetCurrentMetaVault();

	// Mutations
	const {
		data: subHash,
		writeContract: subVault,
		isPending: subPending,
	} = useWriteContract();
	const { isLoading: subLoading, isSuccess: subSuccess } =
		useWaitForTransactionReceipt({
			hash: subHash,
		});

	const handleAddVault = () => {
		subVault({
			abi: metaVaultABI,
			address: metaVaultAddress as `0x${string}`,
			functionName: "addVault",
			args: [vaultAddress as `0x${string}`, 100n],
		});
	};

	return (
		<IconButton
			alignSelf={"center"}
			colorPalette={"green"}
			rounded={"full"}
			onClick={handleAddVault}
			loading={subPending || subLoading}
			disabled={subPending || subSuccess}
		>
			<LuPlus />
		</IconButton>
	);
}
