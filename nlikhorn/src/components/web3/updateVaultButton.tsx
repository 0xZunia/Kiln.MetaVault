import { useGetCurrentMetaVault } from "@/hooks/metaVault";
import { metaVaultABI } from "@/utils/metaVaultABI";
import { IconButton } from "@chakra-ui/react";
import { useEffect } from "react";
import { LuPlus, LuTrash2 } from "react-icons/lu";
import {
	useReadContract,
	useWaitForTransactionReceipt,
	useWriteContract,
} from "wagmi";

export function UpdateVaultButton({
	vaultAddress,
}: {
	vaultAddress: string;
}) {
	const { vaultAddress: metaVaultAddress } = useGetCurrentMetaVault();
	const { data: activeVaults, refetch } = useReadContract({
		abi: metaVaultABI,
		address: metaVaultAddress,
		functionName: "getActiveVaults",
	});

	const isActive = activeVaults?.some(
		(vault) => vault.toLowerCase() === vaultAddress.toLowerCase(),
	);

	// Add vault
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

	// Remove vault
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

	useEffect(() => {
		if (subSuccess || unsubSuccess) {
			refetch();
		}
	}, [refetch, subSuccess, unsubSuccess]);

	return isActive ? (
		<IconButton
			alignSelf={"center"}
			colorPalette={"red"}
			// rounded={"full"}
			onClick={handleRemoveVault}
			loading={unsubPending || unsubLoading}
			disabled={unsubPending || unsubSuccess}
			variant={"subtle"}
		>
			<LuTrash2 />
		</IconButton>
	) : (
		<IconButton
			alignSelf={"center"}
			colorPalette={"green"}
			// rounded={"full"}
			onClick={handleAddVault}
			loading={subPending || subLoading}
			disabled={subPending || subSuccess}
			variant={"subtle"}
		>
			<LuPlus />
		</IconButton>
	);
}
