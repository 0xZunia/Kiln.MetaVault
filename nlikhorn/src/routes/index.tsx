import { config } from "@/utils/config";
import { factoryABI } from "@/utils/factoryABI";
import { Box, Button, VStack } from "@chakra-ui/react";
import { createFileRoute } from "@tanstack/react-router";
import { useContext } from "react";
import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { HeadingContext } from "./__root";

export const Route = createFileRoute("/")({
	component: Index,
});

const FACTORY_ADDRESS = "0x9f2aFA649C0b23661fB51D12ba6fFc552E675507";

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
