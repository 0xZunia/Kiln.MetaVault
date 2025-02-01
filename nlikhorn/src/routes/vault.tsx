import { createFileRoute } from "@tanstack/react-router";
import { Grid, Skeleton } from "@chakra-ui/react";
import { TotalFounds } from "@/components/custom/MetaVault";

export const Route = createFileRoute("/vault")({
	component: RouteComponent,
});

function RouteComponent() {
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
