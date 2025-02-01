import {
	Button,
	Link as ChakraLink,
	Container,
	HStack,
	useBreakpointValue,
} from "@chakra-ui/react";
import { Link, useLocation } from "@tanstack/react-router";
import { LuHouse, LuPiggyBank, LuVault } from "react-icons/lu";

const HERE_PALLETE = "orange";
const NOT_HERE_PALLETE = "grey";

export function NavBar() {
	const isMobile = useBreakpointValue({ base: true, xl: false });

	const { pathname } = useLocation();

	const isHere = (path: string) => path === pathname;

	return (
		<Container
			zIndex={"sticky"}
			position={"sticky"}
			bottom={3}
			left={0}
			padding={0}
		>
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
				<ChakraLink asChild flex={1}>
					<Link to="/">
						<Button width={"full"} colorPalette={isHere("/") ? "" : "gray"}>
							<LuHouse /> {!isMobile && "Dashboard"}
						</Button>
					</Link>
				</ChakraLink>

				<ChakraLink asChild flex={2}>
					<Link to="/vault">
						<Button
							width={"full"}
							colorPalette={isHere("/vault") ? "" : "gray"}
						>
							<LuVault /> {!isMobile && "MetaVault"}
						</Button>
					</Link>
				</ChakraLink>

				<ChakraLink asChild flex={1}>
					<Link to="/earn">
						<Button width={"full"} colorPalette={isHere("/earn") ? "" : "gray"}>
							<LuPiggyBank />
							{!isMobile && "Earn"}
						</Button>
					</Link>
				</ChakraLink>
			</HStack>
		</Container>
	);
}
