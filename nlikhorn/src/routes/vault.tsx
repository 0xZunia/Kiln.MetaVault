import { SimpleLoader } from "@/components/custom/simpleLoader";
import { Avatar } from "@/components/ui/avatar";
import { UpdateVaultButton } from "@/components/web3/updateVaultButton";
import { useGetMetaVault } from "@/hooks/factory";
import { addressConfig } from "@/utils/addressConfig";
import { factoryABI } from "@/utils/factoryABI";
import { fetchOnKiln } from "@/utils/kilnConnectFetch";
import {
	Button,
	Card,
	DataList,
	FormatNumber,
	Grid,
	GridItem,
	Skeleton,
	Stat,
	Text,
} from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { useMemo } from "react";
import { useAccount, useWriteContract } from "wagmi";

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

	return <VaultListing />;
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

function VaultListing() {
	// Create a query using tanstack/react-query
	const { data: vaultList, isLoading } = useQuery({
		queryKey: ["kiln_vaults"],
		queryFn: async () => {
			const resp = await fetchOnKiln("/deployments");

			const activeVaults = resp?.data.filter(
				(vault: Vault) => vault.status === "active",
			);

			return activeVaults as Vault[];
		},
	});

	const ethVaultsAddr = useMemo(() => {
		const ret = addressConfig.VAULT_ADDRESS;

		if (vaultList) {
			ret.push(
				...vaultList
					.filter((v) => v.chain === "eth")
					.map((v) => v.address as `0x${string}`),
			);
		}
		return ret;
	}, [vaultList]);

	const { data: networkStats } = useQuery({
		queryKey: ["kiln_stats"],
		queryFn: async () => {
			const resp = await fetchOnKiln(
				`/defi/network-stats?vaults=${ethVaultsAddr.map((addr) => `eth_${addr}`).join(",")}`,
			);

			const stats = resp?.data;

			return stats as NetworkStats[];
		},
	});

	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, auto)"}
			gap={2}
		>
			<GridItem colSpan={2}>
				<Skeleton loading={isLoading} height={"full"}>
					<Card.Root>
						<Card.Body>
							<Card.Title>Vaults kiln</Card.Title>
							<DataList.Root orientation="horizontal" divideY="1px">
								{networkStats?.map((stats) => (
									<NetworkStatsItem key={stats.vault} stats={stats} />
								))}
								{vaultList
									?.filter((vault) => vault.chain !== "eth")
									.map((vault) => (
										<VaultItem key={vault.id} vault={vault} />
									))}
							</DataList.Root>
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
	return (
		<DataList.Item>
			<DataList.ItemLabel>
				<Avatar size={"xs"} />
				{vault.display_name}
			</DataList.ItemLabel>
			<DataList.ItemValue gap={2}>
				<Stat.Root>
					<Stat.Label>NRR</Stat.Label>
					<Stat.ValueText>--</Stat.ValueText>
				</Stat.Root>
				<Stat.Root>
					<Stat.Label>Chain</Stat.Label>
					<Stat.ValueText>{vault.chain}</Stat.ValueText>
				</Stat.Root>
				<Text>Comming soon...</Text>
			</DataList.ItemValue>
		</DataList.Item>
	);
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
		<DataList.Item>
			<DataList.ItemLabel>
				<Avatar src={stats.asset_icon} size={"xs"} />
				{stats.protocol_display_name}
			</DataList.ItemLabel>
			<DataList.ItemValue>
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
				<Stat.Root>
					<Stat.Label>Chain</Stat.Label>
					<Stat.ValueText>{stats.chain}</Stat.ValueText>
				</Stat.Root>

				<UpdateVaultButton vaultAddress={stats.vault} />
			</DataList.ItemValue>
		</DataList.Item>
	);
}
