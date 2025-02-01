import { Box, VStack } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { useContext } from "react";
import { HeadingContext } from "./__root";

export const Route = createFileRoute("/")({
	component: Index,
});

function Index() {
	const { setHeading } = useContext(HeadingContext);

	setHeading("Index");

	return (
		<VStack gap={1} width={"full"}>
			<Box w={"full"} bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
			<Box bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
			<Box bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
			<Box bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
			<Box bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
			<Box bgColor={"bg.subtle"} height={"200px"}>
				Here in index
			</Box>
		</VStack>
	);
}
