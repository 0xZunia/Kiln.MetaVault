import {
	Link as ChakraLink,
	Container,
	HStack,
	IconButton,
} from "@chakra-ui/react";
import { Link } from "@tanstack/react-router";
import { LuCheck, LuHouse, LuSearch } from "react-icons/lu";

export function NavBar() {
	return (
		<Container position={"absolute"} bottom={3} left={0}>
			<HStack
				justify={"space-around"}
				paddingY={2}
				paddingX={3}
				rounded={"md"}
				shadow={"sm"}
				borderWidth={"1px"}
				borderColor={"border"}
				colorPalette={"orange"}
				bgColor={"bg"}
			>
				<IconButton>
					<LuHouse />
				</IconButton>
				<IconButton>
					<LuSearch />
				</IconButton>
				<IconButton>
					<LuCheck />
				</IconButton>
			</HStack>
		</Container>
	);
}
