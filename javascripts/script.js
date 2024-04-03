gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray('.product').forEach((product, index) => {
    gsap.from(product, {
        opacity: 0,
        y: 100,
        duration: 1,
        scrollTrigger: {
            trigger: product,
            start: 'top 80%',
            end: 'top 50%',
            toggleActions: 'play none none reverse',
        },
    });
});
