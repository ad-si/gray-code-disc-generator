import { program } from "commander"
import { generateDiscSVG } from "./index"

program
  .option("--resolution <value>", "Resolution of the disc", parseInt)
  .action((options) => {
    const svg = generateDiscSVG(options)
    console.info(svg)
  })

program.parse()
