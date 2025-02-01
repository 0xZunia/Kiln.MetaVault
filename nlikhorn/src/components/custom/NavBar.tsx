import { Container, HStack, IconButton } from "@chakra-ui/react";
import { LuHouse, LuSearch, LuCheck } from "react-icons/lu";

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
