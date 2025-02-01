import { TotalFounds } from "@/components/custom/MetaVault";
import { SimpleLoader } from "@/components/custom/simpleLoader";
import { useGetMetaVault } from "@/hooks/factory";
import { addressConfig } from "@/utils/addressConfig";
import { factoryABI } from "@/utils/factoryABI";
import { Button, Card, Grid, Skeleton } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { useMemo } from "react";
import { useAccount, useWriteContract } from "wagmi";

export const Route = createFileRoute("/vault")({
	component: RouteComponent,
});

function RouteComponent() {
	const { address } = useAccount();
	const { data, isLoading } = useGetMetaVault(address);
	console.log(data);

	const hasVault = useMemo(() => {
		return (
			data &&
			data !== "0x" &&
			data !== "0x0000000000000000000000000000000000000000"
		);
	}, [data]);

	if (isLoading) {
		return <SimpleLoader />;
	}

	if (!hasVault) {
		return <CreateVaultCard />;
	}

	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, 1fr)"}
			gap={2}
		>
			<TotalFounds />
			<Skeleton id="total founds" width={"full"} />
			<Skeleton id="available founds" width={"full"} />
		</Grid>
	);
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
