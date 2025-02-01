import { Grid, GridItem, Skeleton } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { TotalFounds } from "@/components/custom/MetaVault";

export const Route = createFileRoute("/")({
	component: Index,
});

function Index() {
	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, 1fr)"}
			gap={2}
		>
			<GridItem colSpan={2} width={"full"}>
				<Skeleton id="total founds" width={"full"} />
			</GridItem>
			<TotalFounds />
			<Skeleton id="available founds" width={"full"} />
		</Grid>
	);
}
