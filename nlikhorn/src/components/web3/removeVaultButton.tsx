import { useGetCurrentMetaVault } from "@/hooks/metaVault";
import { metaVaultABI } from "@/utils/metaVaultABI";
import { IconButton } from "@chakra-ui/react";
import { LuPlus } from "react-icons/lu";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";

export function RemoveVaultButton({
	vaultAddress,
}: {
	vaultAddress: string;
}) {
	const { vaultAddress: metaVaultAddress } = useGetCurrentMetaVault();

	// Mutations
	const {
		data: unsubHash,
		writeContract: unsubVault,
		isPending: unsubPending,
	} = useWriteContract();
	const { isLoading: unsubLoading, isSuccess: unsubSuccess } =
		useWaitForTransactionReceipt({
			hash: unsubHash,
		});

	const handleRemoveVault = () => {
		unsubVault({
			abi: metaVaultABI,
			address: metaVaultAddress as `0x${string}`,
			functionName: "removeVault",
			args: [vaultAddress as `0x${string}`],
		});
	};

	return (
		<IconButton
			alignSelf={"center"}
			colorPalette={"red"}
			rounded={"full"}
			onClick={handleRemoveVault}
			loading={unsubPending || unsubLoading}
			disabled={unsubPending || unsubSuccess}
		>
			<LuPlus style={{ transform: "rotate(45deg)" }} />
		</IconButton>
	);
}
