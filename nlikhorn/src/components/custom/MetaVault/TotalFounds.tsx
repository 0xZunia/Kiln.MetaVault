import { Box, Skeleton } from "@chakra-ui/react";

export default function TotalFounds() {
	return (
		<Skeleton loading={false} id="nb of active vault" width={"full"}>
			<Box rounded={"md"} padding={2} boxSize={"full"} bgColor={"bg.subtle"}>
				123
			</Box>
		</Skeleton>
	);
}
