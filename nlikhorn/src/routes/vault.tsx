import { TotalFounds } from "@/components/custom/MetaVault";
import { SimpleLoader } from "@/components/custom/simpleLoader";
import { Avatar } from "@/components/ui/avatar";
import { useGetMetaVault } from "@/hooks/factory";
import { addressConfig } from "@/utils/addressConfig";
import { factoryABI } from "@/utils/factoryABI";
import { metaVaultABI } from "@/utils/metaVaultABI";
import {
	Box,
	Button,
	Card,
	Grid,
	HStack,
	Skeleton,
	VStack,
	Text,
	GridItem,
	Stat,
	FormatNumber,
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
	const { writeContract, isPending: writeContractIsPending } =
		useWriteContract();

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
				<Button loading={writeContractIsPending} onClick={handleSubmit}>
					Create Vault
				</Button>
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
	const { data: vaultList, isLoading } = useQuery({
		queryKey: ["kiln_vaults"],
		queryFn: async () => {
			const resp = await fetch(
				`https://api${import.meta.env.DEV && ".testnet"}.kiln.fi/v1/deployments`,
				{
					headers: {
						Authorization: `Bearer ${import.meta.env.VITE_KILN_API_KEY}`,
					},
				},
			).then((res) => res.json());

			const activeVaults = resp?.data.filter(
				(vault: Vault) => vault.status === "active",
			);

			return activeVaults as Vault[];
		},
	});

	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, 1fr)"}
			gap={2}
		>
			<TotalFounds />
			<Skeleton id="total founds" width={"full"} />
			<GridItem colSpan={2}>
				<Skeleton loading={isLoading}>
					<Card.Root>
						<Card.Body>
							<Card.Title>Vaults kiln</Card.Title>
							<VStack align="left">
								{vaultList?.map((vault) => (
									<VaultItem key={vault.id} vault={vault} />
								))}
							</VStack>
						</Card.Body>
					</Card.Root>
				</Skeleton>
			</GridItem>
		</Grid>
	);
}

export type Vault = {
	id: string;
	organization_id: string;
	product_type: string;
	name: string;
	display_name: string;
	description: string;
	chain: string;
	chain_id: number;
	address: string;
	status: "disabled" | "active";
	asset_icon: string | null;
	protocol_icon: string | null;
	product_fee: string;
};

function VaultItem({ vault }: { vault: Vault }) {
	if (vault.chain === "eth") {
		const { data: networkStats, isLoading } = useQuery({
			queryKey: ["kiln_stats"],
			queryFn: async () => {
				const resp = await fetch(
					`https://api${import.meta.env.DEV && ".testnet"}.kiln.fi/v1/defi/network-stats?vaults=eth_${vault.address}`,
					{
						headers: {
							Authorization: `Bearer ${import.meta.env.VITE_KILN_API_KEY}`,
						},
					},
				).then((res) => res.json());

				const activeVaults = resp?.data[0];

				return activeVaults as NetworkStats;
			},
		});

		if (!networkStats) return;
		return <NetworkStatsItem stats={networkStats} />;
	}

	return <Box>{vault.display_name}</Box>;
}

export type NetworkStats = {
	asset: string;
	asset_icon: string;
	asset_symbol: string;
	asset_decimals: number;
	asset_price_usd: number;
	share_symbol: string;
	vault: string;
	tvl: string;
	protocol: string;
	protocol_display_name: string;
	protocol_icon: string;
	protocol_tvl: string;
	protocol_supply_limit: string;
	grr: number;
	nrr: number;
	chain: string;
	chain_id: number;
	updated_at_block: number;
};

function NetworkStatsItem({ stats }: { stats: NetworkStats }) {
	return (
		<HStack>
			<Avatar src={stats.asset_icon} size={"xs"} />
			<Text>{stats.protocol_display_name}</Text>
			<Stat.Root>
				<Stat.Label>NRR</Stat.Label>
				<Stat.ValueText>
					<FormatNumber
						value={stats.nrr / 100}
						style="percent"
						maximumFractionDigits={2}
					/>
				</Stat.ValueText>
			</Stat.Root>
			<Text>{stats.chain}</Text>
		</HStack>
	);
}
