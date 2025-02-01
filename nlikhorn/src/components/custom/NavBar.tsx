import { Container, HStack, IconButton } from "@chakra-ui/react";
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
				<IconButton as={Link} to="/">
					<LuHouse />
				</IconButton>
				<IconButton as={Link} to="/search">
					<LuSearch />
				</IconButton>
				<IconButton as={Link} to="/earn">
					<LuCheck />
				</IconButton>
			</HStack>
		</Container>
	);
}
