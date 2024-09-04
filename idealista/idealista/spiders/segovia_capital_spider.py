from idealista.spiders.core import Core


class MadridViviendaSpider(Core):
    name = "segovia-segovia"

    def __init__(self):
        super(MadridViviendaSpider, self).__init__(self.name, "alquiler", "viviendas")
