import QtQuick

QtObject {
    id: root

    readonly property var raw: [
        ["H", "Hydrogen", "1.008", "-259.2", "-252.9", "0.0899", "1s1"],
        ["He", "Helium", "4.0026", "—", "-268.9", "0.1786", "1s2"],
        ["Li", "Lithium", "6.94", "180.5", "1342", "0.534", "2s1"],
        ["Be", "Beryllium", "9.0122", "1287", "2470", "1.85", "2s2"],
        ["B", "Boron", "10.81", "2076", "3927", "2.34", "2s2 2p1"],
        ["C", "Carbon", "12.011", "—", "3642 (subl.)", "2.27", "2s2 2p2"],
        ["N", "Nitrogen", "14.007", "-210.0", "-195.8", "1.251", "2s2 2p3"],
        ["O", "Oxygen", "15.999", "-218.8", "-183.0", "1.429", "2s2 2p4"],
        ["F", "Fluorine", "18.998", "-219.7", "-188.1", "1.696", "2s2 2p5"],
        ["Ne", "Neon", "20.180", "-248.6", "-246.1", "0.900", "2s2 2p6"],
        ["Na", "Sodium", "22.990", "97.8", "883", "0.971", "3s1"],
        ["Mg", "Magnesium", "24.305", "650", "1090", "1.74", "3s2"],
        ["Al", "Aluminium", "26.982", "660.3", "2470", "2.70", "3s2 3p1"],
        ["Si", "Silicon", "28.085", "1414", "3265", "2.33", "3s2 3p2"],
        ["P", "Phosphorus", "30.974", "44.2", "280.5", "1.82", "3s2 3p3"],
        ["S", "Sulfur", "32.06", "115.2", "444.6", "2.07", "3s2 3p4"],
        ["Cl", "Chlorine", "35.45", "-101.5", "-34.0", "3.214", "3s2 3p5"],
        ["Ar", "Argon", "39.948", "-189.3", "-185.8", "1.784", "3s2 3p6"],
        ["K", "Potassium", "39.098", "63.5", "759", "0.862", "4s1"],
        ["Ca", "Calcium", "40.078", "842", "1484", "1.55", "4s2"],
        ["Sc", "Scandium", "44.956", "1541", "2836", "2.99", "3d1 4s2"],
        ["Ti", "Titanium", "47.867", "1668", "3287", "4.51", "3d2 4s2"],
        ["V", "Vanadium", "50.942", "1910", "3407", "6.11", "3d3 4s2"],
        ["Cr", "Chromium", "51.996", "1907", "2671", "7.15", "3d5 4s1"],
        ["Mn", "Manganese", "54.938", "1246", "2061", "7.21", "3d5 4s2"],
        ["Fe", "Iron", "55.845", "1538", "2862", "7.87", "3d6 4s2"],
        ["Co", "Cobalt", "58.933", "1495", "2927", "8.90", "3d7 4s2"],
        ["Ni", "Nickel", "58.693", "1455", "2913", "8.91", "3d8 4s2"],
        ["Cu", "Copper", "63.546", "1085", "2562", "8.96", "3d10 4s1"],
        ["Zn", "Zinc", "65.38", "419.5", "907", "7.14", "3d10 4s2"],
        ["Ga", "Gallium", "69.723", "29.8", "2204", "5.91", "3d10 4s2 4p1"],
        ["Ge", "Germanium", "72.630", "938", "2833", "5.32", "3d10 4s2 4p2"],
        ["As", "Arsenic", "74.922", "817", "614 (subl.)", "5.73", "3d10 4s2 4p3"],
        ["Se", "Selenium", "78.971", "221", "685", "4.81", "3d10 4s2 4p4"],
        ["Br", "Bromine", "79.904", "-7.2", "58.8", "3.10", "3d10 4s2 4p5"],
        ["Kr", "Krypton", "83.798", "-157.4", "-153.4", "3.749", "3d10 4s2 4p6"],
        ["Rb", "Rubidium", "85.468", "39.3", "688", "1.53", "5s1"],
        ["Sr", "Strontium", "87.62", "777", "1382", "2.64", "5s2"],
        ["Y", "Yttrium", "88.906", "1526", "3345", "4.47", "4d1 5s2"],
        ["Zr", "Zirconium", "91.224", "1855", "4409", "6.51", "4d2 5s2"],
        ["Nb", "Niobium", "92.906", "2477", "4744", "8.57", "4d4 5s1"],
        ["Mo", "Molybdenum", "95.95", "2623", "4639", "10.28", "4d5 5s1"],
        ["Tc", "Technetium", "98", "2157", "4265", "11.5", "4d5 5s2"],
        ["Ru", "Ruthenium", "101.07", "2334", "4150", "12.37", "4d7 5s1"],
        ["Rh", "Rhodium", "102.91", "1964", "3695", "12.41", "4d8 5s1"],
        ["Pd", "Palladium", "106.42", "1555", "2963", "12.02", "4d10"],
        ["Ag", "Silver", "107.87", "961.8", "2162", "10.49", "4d10 5s1"],
        ["Cd", "Cadmium", "112.41", "321", "767", "8.65", "4d10 5s2"],
        ["In", "Indium", "114.82", "156.6", "2072", "7.31", "4d10 5s2 5p1"],
        ["Sn", "Tin", "118.71", "231.9", "2602", "7.27", "4d10 5s2 5p2"],
        ["Sb", "Antimony", "121.76", "631", "1587", "6.70", "4d10 5s2 5p3"],
        ["Te", "Tellurium", "127.60", "450", "988", "6.24", "4d10 5s2 5p4"],
        ["I", "Iodine", "126.90", "113.7", "184.3", "4.93", "4d10 5s2 5p5"],
        ["Xe", "Xenon", "131.29", "-111.8", "-108.1", "5.894", "4d10 5s2 5p6"],
        ["Cs", "Cesium", "132.91", "28.5", "671", "1.93", "6s1"],
        ["Ba", "Barium", "137.33", "727", "1845", "3.51", "6s2"],
        ["La", "Lanthanum", "138.91", "920", "3464", "6.15", "5d1 6s2"],
        ["Ce", "Cerium", "140.12", "795", "3443", "6.77", "4f1 5d1 6s2"],
        ["Pr", "Praseodymium", "140.91", "935", "3130", "6.77", "4f3 6s2"],
        ["Nd", "Neodymium", "144.24", "1024", "3074", "7.01", "4f4 6s2"],
        ["Pm", "Promethium", "145", "1042", "3000", "7.26", "4f5 6s2"],
        ["Sm", "Samarium", "150.36", "1072", "1900", "7.52", "4f6 6s2"],
        ["Eu", "Europium", "151.96", "826", "1529", "5.24", "4f7 6s2"],
        ["Gd", "Gadolinium", "157.25", "1312", "3000", "7.90", "4f7 5d1 6s2"],
        ["Tb", "Terbium", "158.93", "1356", "3123", "8.23", "4f9 6s2"],
        ["Dy", "Dysprosium", "162.50", "1407", "2562", "8.55", "4f10 6s2"],
        ["Ho", "Holmium", "164.93", "1461", "2720", "8.80", "4f11 6s2"],
        ["Er", "Erbium", "167.26", "1529", "2868", "9.07", "4f12 6s2"],
        ["Tm", "Thulium", "168.93", "1545", "1950", "9.32", "4f13 6s2"],
        ["Yb", "Ytterbium", "173.05", "824", "1196", "6.90", "4f14 6s2"],
        ["Lu", "Lutetium", "174.97", "1652", "3402", "9.84", "4f14 5d1 6s2"],
        ["Hf", "Hafnium", "178.49", "2233", "4603", "13.31", "4f14 5d2 6s2"],
        ["Ta", "Tantalum", "180.95", "3017", "5458", "16.65", "4f14 5d3 6s2"],
        ["W", "Tungsten", "183.84", "3422", "5555", "19.25", "4f14 5d4 6s2"],
        ["Re", "Rhenium", "186.21", "3186", "5596", "21.02", "4f14 5d5 6s2"],
        ["Os", "Osmium", "190.23", "3033", "5012", "22.59", "4f14 5d6 6s2"],
        ["Ir", "Iridium", "192.22", "2446", "4428", "22.56", "4f14 5d7 6s2"],
        ["Pt", "Platinum", "195.08", "1768", "3825", "21.45", "4f14 5d9 6s1"],
        ["Au", "Gold", "196.97", "1064", "2970", "19.32", "4f14 5d10 6s1"],
        ["Hg", "Mercury", "200.59", "-38.8", "356.7", "13.53", "4f14 5d10 6s2"],
        ["Tl", "Thallium", "204.38", "304", "1473", "11.85", "4f14 5d10 6s2 6p1"],
        ["Pb", "Lead", "207.2", "327.5", "1749", "11.34", "4f14 5d10 6s2 6p2"],
        ["Bi", "Bismuth", "208.98", "271.4", "1564", "9.78", "4f14 5d10 6s2 6p3"],
        ["Po", "Polonium", "209", "254", "962", "9.20", "4f14 5d10 6s2 6p4"],
        ["At", "Astatine", "210", "302", "—", "—", "4f14 5d10 6s2 6p5"],
        ["Rn", "Radon", "222", "-71", "-61.7", "9.73", "4f14 5d10 6s2 6p6"],
        ["Fr", "Francium", "223", "27", "—", "—", "7s1"],
        ["Ra", "Radium", "226", "700", "1737", "5.5", "7s2"],
        ["Ac", "Actinium", "227", "1050", "3200", "10.07", "6d1 7s2"],
        ["Th", "Thorium", "232.04", "1750", "4788", "11.72", "6d2 7s2"],
        ["Pa", "Protactinium", "231.04", "1572", "—", "15.37", "5f2 6d1 7s2"],
        ["U", "Uranium", "238.03", "1135", "4131", "19.1", "5f3 6d1 7s2"],
        ["Np", "Neptunium", "237", "644", "3902", "20.45", "5f4 6d1 7s2"],
        ["Pu", "Plutonium", "244", "640", "3228", "19.82", "5f6 7s2"],
        ["Am", "Americium", "243", "1176", "2607", "13.67", "5f7 7s2"],
        ["Cm", "Curium", "247", "1345", "3110", "13.51", "5f7 6d1 7s2"],
        ["Bk", "Berkelium", "247", "986", "—", "14.78", "5f9 7s2"],
        ["Cf", "Californium", "251", "900", "—", "15.1", "5f10 7s2"],
        ["Es", "Einsteinium", "252", "860", "—", "—", "5f11 7s2"],
        ["Fm", "Fermium", "257", "1527", "—", "—", "5f12 7s2"],
        ["Md", "Mendelevium", "258", "827", "—", "—", "5f13 7s2"],
        ["No", "Nobelium", "259", "827", "—", "—", "5f14 7s2"],
        ["Lr", "Lawrencium", "266", "1627", "—", "—", "5f14 7s2 7p1"],
        ["Rf", "Rutherfordium", "267", "—", "—", "—", "5f14 6d2 7s2"],
        ["Db", "Dubnium", "268", "—", "—", "—", "5f14 6d3 7s2"],
        ["Sg", "Seaborgium", "269", "—", "—", "—", "5f14 6d4 7s2"],
        ["Bh", "Bohrium", "270", "—", "—", "—", "5f14 6d5 7s2"],
        ["Hs", "Hassium", "277", "—", "—", "—", "5f14 6d6 7s2"],
        ["Mt", "Meitnerium", "278", "—", "—", "—", "5f14 6d7 7s2"],
        ["Ds", "Darmstadtium", "281", "—", "—", "—", "5f14 6d8 7s2"],
        ["Rg", "Roentgenium", "282", "—", "—", "—", "5f14 6d9 7s2"],
        ["Cn", "Copernicium", "285", "—", "—", "—", "5f14 6d10 7s2"],
        ["Nh", "Nihonium", "286", "—", "—", "—", "5f14 6d10 7s2 7p1"],
        ["Fl", "Flerovium", "289", "—", "—", "—", "5f14 6d10 7s2 7p2"],
        ["Mc", "Moscovium", "290", "—", "—", "—", "5f14 6d10 7s2 7p3"],
        ["Lv", "Livermorium", "293", "—", "—", "—", "5f14 6d10 7s2 7p4"],
        ["Ts", "Tennessine", "294", "—", "—", "—", "5f14 6d10 7s2 7p5"],
        ["Og", "Oganesson", "294", "—", "—", "—", "5f14 6d10 7s2 7p6"]
    ]

    readonly property var gases: [1, 2, 7, 8, 9, 10, 17, 18, 36, 54, 86]
    readonly property var liquids: [31, 35, 55, 80, 87]

    function position(z) {
        if (z === 1) return { g: 1, p: 1, f: -1, i: 0 }
        if (z === 2) return { g: 18, p: 1, f: -1, i: 0 }
        if (z <= 4) return { g: z - 2, p: 2, f: -1, i: 0 }
        if (z <= 10) return { g: z + 8, p: 2, f: -1, i: 0 }
        if (z <= 12) return { g: z - 10, p: 3, f: -1, i: 0 }
        if (z <= 18) return { g: z, p: 3, f: -1, i: 0 }
        if (z <= 36) return { g: z - 18, p: 4, f: -1, i: 0 }
        if (z <= 54) return { g: z - 36, p: 5, f: -1, i: 0 }
        if (z <= 56) return { g: z - 54, p: 6, f: -1, i: 0 }
        if (z === 57) return { g: 3, p: 6, f: -1, i: 0 }
        if (z <= 71) return { g: 0, p: 6, f: 0, i: z - 58 }
        if (z <= 86) return { g: z - 68, p: 6, f: -1, i: 0 }
        if (z <= 88) return { g: z - 86, p: 7, f: -1, i: 0 }
        if (z === 89) return { g: 3, p: 7, f: -1, i: 0 }
        if (z <= 103) return { g: 0, p: 7, f: 1, i: z - 90 }
        return { g: z - 100, p: 7, f: -1, i: 0 }
    }

    function kindOf(z) {
        if (z === 43 || z === 61 || z >= 93) return "synth"
        if (gases.indexOf(z) >= 0) return "gas"
        if (liquids.indexOf(z) >= 0) return "liquid"
        return "solid"
    }

    function toneFor(kind) {
        if (kind === "gas") return "#ff8a3d"
        if (kind === "liquid") return "#ffd23f"
        if (kind === "synth") return "#ff7ab6"
        return "#5cc6f5"
    }

    function kindLabel(kind) {
        if (kind === "gas") return "Gas"
        if (kind === "liquid") return "Liquid"
        if (kind === "synth") return "Synthetic"
        return "Solid"
    }

    function coreOf(z) {
        if (z <= 2) return ""
        if (z <= 10) return "[He] "
        if (z <= 18) return "[Ne] "
        if (z <= 36) return "[Ar] "
        if (z <= 54) return "[Kr] "
        if (z <= 86) return "[Xe] "
        return "[Rn] "
    }

    function shellsOf(z, rest) {
        const cores = {
            "": [], "[He] ": [2], "[Ne] ": [2, 8], "[Ar] ": [2, 8, 8],
            "[Kr] ": [2, 8, 18, 8], "[Xe] ": [2, 8, 18, 18, 8], "[Rn] ": [2, 8, 18, 32, 18, 8]
        }
        const s = cores[coreOf(z)].slice()
        const re = /(\d)([spdf])(\d+)/g
        let m
        while ((m = re.exec(rest)) !== null) {
            const n = parseInt(m[1])
            while (s.length < n) s.push(0)
            s[n - 1] += parseInt(m[3])
        }
        return s
    }

    function formatTemp(v) {
        if (v === "—") return v
        const i = v.indexOf(" (")
        return i < 0 ? v + " °C" : v.slice(0, i) + " °C" + v.slice(i)
    }

    function build() {
        const out = []
        for (let k = 0; k < raw.length; k++) {
            const r = raw[k]
            const z = k + 1
            const pos = position(z)
            const kind = kindOf(z)
            const unstable = z === 43 || z === 61 || (z >= 84 && z <= 89) || z >= 93
            const cfg = (coreOf(z) + r[6]).replace(/([spdf])(\d+)/g, "$1<sup>$2</sup>")
            out.push({
                z: z, sym: r[0], name: r[1],
                massText: unstable ? "(" + r[2] + ")" : r[2],
                mp: r[3], bp: r[4],
                dens: r[5] === "—" ? "—" : r[5] + (kind === "gas" ? " g/L" : " g/cm³"),
                cfg: cfg + (z >= 104 ? " (predicted)" : ""),
                shells: shellsOf(z, r[6]),
                kind: kind, tone: toneFor(kind),
                g: pos.g, p: pos.p, f: pos.f, i: pos.i
            })
        }
        return out
    }

    readonly property var elements: build()
}
