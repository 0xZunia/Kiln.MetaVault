import { Grid, Skeleton } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { useContext } from "react";
import { HeadingContext } from "./__root";

export const Route = createFileRoute("/")({
	component: Index,
});

function Index() {
	const { setHeading } = useContext(HeadingContext);
	setHeading("Dashboard");

	return (
		<Grid
			gridTemplateColumns={"repeat(2, 1fr)"}
			gridTemplateRows={"repeat(2, 1fr)"}
			gap={2}
		>
			<Skeleton id="nb of active vault" width={"full"} />
			<Skeleton id="total founds" width={"full"} />
			<Skeleton id="available founds" width={"full"} />
		</Grid>
	);
}
