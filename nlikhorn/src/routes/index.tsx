import { Box } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { useContext } from "react";
import { HeadingContext } from "./__root";

export const Route = createFileRoute("/")({
	component: Index,
});

function Index() {
	const { setHeading } = useContext(HeadingContext);

	setHeading("Index");

	return <Box>Here in index</Box>;
}
