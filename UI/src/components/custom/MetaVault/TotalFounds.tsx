import { Box, Skeleton } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { useBalance } from "wagmi";

export default function TotalFounds() {
	const [isLoading, setLoading] = useState(true);

	useBalance;
	useEffect(() => {
		setTimeout(() => setLoading(false), 2000);
	});

	return (
		<Skeleton loading={isLoading} id="nb of active vault" boxSize={"full"}>
			<Box rounded={"md"} padding={2} boxSize={"full"} bgColor={"bg.subtle"}>
				123
			</Box>
		</Skeleton>
	);
}
