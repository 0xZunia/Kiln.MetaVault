import { TotalFounds } from "@/components/custom/MetaVault";
import { SimpleLoader } from "@/components/custom/simpleLoader";
import { useGetMetaVault } from "@/hooks/factory";
import { addressConfig } from "@/utils/addressConfig";
import { factoryABI } from "@/utils/factoryABI";
import { metaVaultABI } from "@/utils/metaVaultABI";
import {
	Button,
	Card,
	Grid,
	HStack,
	Skeleton,
	Text,
	VStack,
} from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { useMemo } from "react";
import { useAccount, useReadContract, useWriteContract } from "wagmi";

export const Route = createFileRoute("/vault")({
	component: RouteComponent,
});

function RouteComponent() {
	const { address } = useAccount();
	const { data: vaultAddress, isLoading } = useGetMetaVault(address);

	const hasVault = useMemo(() => {
		return (
			vaultAddress &&
			vaultAddress !== "0x" &&
			vaultAddress !== "0x0000000000000000000000000000000000000000"
		);
	}, [vaultAddress]);

	if (isLoading) {
		return <SimpleLoader />;
	}

	if (!hasVault) {
		return <CreateVaultCard />;
	}

	return <VaultManager vaultAddress={vaultAddress as `0x${string}`} />;
}

function CreateVaultCard() {
	const { address } = useAccount();
	const { writeContract } = useWriteContract();

	const handleSubmit = () => {
		writeContract({
			abi: factoryABI,
			address: addressConfig.FACTORY_ADDRESS,
			functionName: "createMetaVault",
		});
	};

	return (
		<Card.Root>
			<Card.Body>
				<Card.Title>No vault found</Card.Title>
				<Card.Description>
					You do not have a vault for {address}, please create one to continue
				</Card.Description>
			</Card.Body>

			<Card.Footer>
				<Button onClick={handleSubmit}>Create Vault</Button>
			</Card.Footer>
		</Card.Root>
	);
}

function VaultManager({ vaultAddress }: { vaultAddress: `0x${string}` }) {
	// Getter
	const { data: allocation } = useReadContract({
		abi: metaVaultABI,
		address: vaultAddress,
		functionName: "getTotalAllocation",
	});
	const { data: getActiveVaults } = useReadContract({
		abi: metaVaultABI,
		address: vaultAddress,
		functionName: "getActiveVaults",
	});
	const { data: shouldRebalance } = useReadContract({
		abi: metaVaultABI,
		address: vaultAddress,
		functionName: "shouldRebalance",
	});
	console.log({ allocation, getActiveVaults, shouldRebalance });

	// Create a query using tanstack/react-query
	const { data } = useQuery({
		queryKey: ["kiln_vaults"],
		queryFn: () =>
			fetch(
				`https://api${import.meta.env.DEV && ".testnet"}.kiln.fi/v1/deployments`,
				{
					headers: {
						Authorization: `Bearer ${import.meta.env.VITE_KILN_API_KEY}`,
					},
				},
			).then((res) => res.json()),
	});
	const vaultList = data?.data?.filter(
		(vault: { status: string; chain: string }) => vault.status === "active",
	);

	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, 1fr)"}
			gap={2}
		>
			<TotalFounds />
			<Skeleton id="total founds" width={"full"} />
			<Skeleton id="available founds" width={"full"} />
			<VStack justify="center">
				{vaultList?.map((vault: { address: string; description: string }) => (
					<Text key={vault.address}>{vault.description}</Text>
				))}
			</VStack>
		</Grid>
	);
}
